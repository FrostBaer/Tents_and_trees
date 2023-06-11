defmodule Nhf1 do
  @moduledoc """
  Sátrak
  @author "Deák Orsolya <odeak@edu.bme.hu>"
  @date   "2021-10-12"
  """

  # coordinate types
  # sor száma (1-től n-ig)
  @type row :: integer
  # oszlop száma (1-től m-ig)
  @type col :: integer
  # egy parcella koordinátái
  @type field :: {row, col}

  # row types
  # a sátrak száma soronként
  @type tentsCountRows :: [integer]
  # a sátrak száma oszloponként
  @type tentsCountCols :: [integer]

  # a fákat tartalmazó parcellák koordinátái
  @type trees :: [field]
  # a feladványleíró hármas
  @type puzzle_desc :: {tentsCountRows, tentsCountCols, trees}

  # direction types
  # a sátorpozícikók iránya: North, East, South, West
  @type dir :: :N | :E | :S | :W
  # a sátorpozíciók irányának listája a fákhoz képest
  @type tent_dirs :: [dir]

  # error types
  # a fák száma a kertben
  @type cnt_tree :: integer
  # a sátrak száma a kertben
  @type cnt_tent :: integer
  # különbözik egymástól a sátrak és a fák száma
  @type err_diff :: %{err_diff: [{cnt_tree, cnt_tent}]}
  # a sátrak száma rossz a felsorolt sorokban
  @type err_rows :: %{err_rows: [integer]}
  # a sátrak száma rossz a felsorolt oszlopokban
  @type err_cols :: %{err_cols: [integer]}
  # a felsorolt koordinátájú sátrak másikat érintenek
  @type err_touch :: %{err_touch: [field]}
  # hibaleíró négyes
  @type errs_desc :: {err_diff, err_rows, err_cols, err_touch}

  @spec to_internal(file :: String.t()) :: pd :: puzzle_desc
  # A file fájlban szövegesen ábrázolt feladvány leírója pd
  def to_internal(nil), do: nil

  def to_internal(file) do
    file = File.read!(file)
    file = Enum.filter(trim(file), fn z -> z != [] end)
    [h | t] = file
    col = parse(h)
    row = row_nums(t) |> parse()
    field = field_coords(t) |> remove_nil() |> List.flatten()
    {row, col, field}
  end

  @spec parse(list :: [binary()]) :: [Integer]
  # integerré konvertálja a kapott listát
  defp parse(list) do
    for i <- list do
      {n, _} = Integer.parse(i)
      n
    end
  end

  @spec to_rows(file :: binary()) :: [binary()]
  # a kapott listát a sorvége karakter mentén több listára bontja
  defp to_rows(file) do
    String.split(file, "\n")
  end

  @spec spaces(file :: binary()) :: [binary()]
  # eltávolítja a space karaktereket a kapott listákból
  defp spaces(file) do
    spaces_pattern = :binary.compile_pattern([" ", "\t", "\v", "\r"])
    for x <- to_rows(file), do: String.split(x, spaces_pattern)
  end

  @spec trim(file :: binary()) :: [binary()]
  # eltávolítja az üres elemeket a kapott listából
  defp trim(file) do
    for x <- spaces(file), do: Enum.filter(x, fn z -> z != "" end)
  end

  @spec row_nums(rows :: [[String]]) :: [String]
  # visszaadja a sorok első elemét (sátor dbszám/sor)
  defp row_nums(rows) do
    for row <- rows do
      [h | _] = row
      h
    end
  end

  @spec field_coords(rows :: [[String]]) :: [{row, col} | nil]
  # meghatározza a * karakterek (fa) helyét a mátrixban
  defp field_coords(rows) do
    for row <- Enum.with_index(rows) do
      {[_ | t], i} = row

      for x <- Enum.with_index(t) do
        {r, j} = x
        if r == "*", do: {i + 1, j + 1}
      end
    end
  end

  @spec remove_nil(list :: [{row, col} | nil]) :: [{row, col}]
  # a nil elemeket eltávolítja a kapott listából
  defp remove_nil(list) do
    for x <- list, do: Enum.filter(x, fn z -> z != nil end)
  end

  @spec to_external(pd :: puzzle_desc, ds :: tent_dirs, file :: String.t()) :: :ok
  # Az {rs, cs, ts} = pd feladványleíró és a ds sátorirány-lista alapján
  # a feladvány szöveges ábrázolását írja ki a file fájlba, ahol
  #   rs a sátrak soronként elvárt számának a listája,
  #   cs a sátrak oszloponként elvárt számának a listája,
  #   ts a fákat tartalmazó parcellák koordinátájának listája
  def to_external(_, [], _), do: :ok
  def to_external([], _, _), do: :ok
  def to_external(_, _, ""), do: :ok
  def to_external(pd, ds, file) do
    {rs, cs, ts} = pd
    tents = calc_tent(ts, ds, {Enum.count(rs), Enum.count(cs)})
    mx = draw_fields(rs, cs, ts, tents)
    mx = [edit_cols(cs) | mx]
    File.write!(file, List.to_string(mx))
  end

  @spec edit_cols(cs :: [integer()]) :: [integer()]
  # megformázza az oszlopok sátor számait
  defp edit_cols(cs) do
    cs = for c <- cs do
      if(c < 0) do "#{c} "
      else " #{c} "
      end
    end
    ["   " | cs ++ ["\n"]]
  end

  @spec draw_fields(
          rs :: [integer()],
          cs :: [integer()],
          ts :: [{integer()}],
          tents :: [{integer()}]
        ) :: [binary()]
  # kirajzolja a játéktáblát az ismert adatok alapján
  defp draw_fields(rs, cs, ts, tents) do
    for row <- Enum.with_index(rs) do
      {r, i} = row

      col =
        for col <- Enum.with_index(cs) do
          {_, j} = col

          if(Enum.find(ts, fn {x, y} -> x == i + 1 and y == j + 1 end) != nil) do
            " * "
          else
            f = Enum.find(tents, fn {x, y, _} -> x == i + 1 and y == j + 1 end)

            if(f != nil) do
              {_, _, z} = f
              " #{z} "
            else
              " - "
            end
          end
        end
        if(r < 0) do
          ["#{r} " | col ++ ["\n"]]
        else
          [" #{r} " | col ++ ["\n"]]
        end
    end
  end

  # meghatározza a sátrak helyét
  @spec calc_tent(fs :: [{Integer}], ds :: tent_dirs(), max_coord :: {Integer, Integer}) :: [{Integer}]
  defp calc_tent(fs, ds, max_coord) do
    {max_x, max_y} = max_coord

    tents = for x <- Enum.with_index(fs) do
      {{row, col}, i} = x
      place_tent(row, col, Enum.at(ds, i))
    end

    Enum.filter(tents, fn {x, y, _} ->
      x > 0 and y > 0 and x <= max_x and y <= max_y
    end)
  end

  @spec place_tent(row :: integer(), col :: integer(), dir :: dir()) ::
          {integer(), integer(), dir()}
  # meghatározza adott sátor helyét az égtájjal együtt
  defp place_tent(row, col, dir) do
    case dir do
      :N -> {row - 1, col, :N}
      :E -> {row, col + 1, :E}
      :S -> {row + 1, col, :S}
      :W -> {row, col - 1, :W}
      _ -> {row, col, :X}
    end
  end

  @spec check_sol(pd :: puzzle_desc, ds :: tent_dirs) :: ed :: errs_desc
  # Az {rs, cs, ts} = pd feladványleíró és a ds sátorirány-lista
  # alapján elvégzett ellenőrzés eredménye a ed hibaleíró, ahol
  #   rs a sátrak soronként elvárt számának a listája,
  #   cs a sátrak oszloponként elvárt számának a listája,
  #   ts a fákat tartalmazó parcellák koordinátájának a listája
  # Az {e_diff, e_rows, e_cols, e_touch} = ed négyes elemei olyan
  # kulcs-érték párok, melyekben a kulcs a hiba jellegére utal, az
  # érték pedig a hibahelyeket felsoroló lista (üres, ha nincs hiba)
  def check_sol(pd, ds) do
    {rs, cs, ts} = pd
    tents = calc_tent(ts, ds, {Enum.count(rs), Enum.count(cs)})

    e_diff = %{err_diff: e_diff(Enum.count(ts), Enum.count(ds))}
    e_rows = %{err_rows: e_rows(rs, tents) |> Enum.filter(&(!is_nil(&1)))}
    e_cols = %{err_cols: e_cols(cs, tents) |> Enum.filter(&(!is_nil(&1)))}

    e_touch = %{
      err_touch:
        e_touch(tents)
        |> Enum.filter(&(!is_nil(&1)))
        |> List.flatten()
    }

    {e_diff, e_rows, e_cols, e_touch}
  end

  @spec e_diff(tcnt :: Integer, dcnt :: Integer) :: [{Integer, Integer}] | []
  # megvizsgálja, hogy a sátrak és fák száma azonos-e
  defp e_diff(tcnt, dcnt) do
    if(tcnt != dcnt) do
      [{tcnt, dcnt}]
    else
      []
    end
  end

  @spec e_rows(rs :: [Integer], tents :: [{Integer, Integer, dir()}]) :: [{Integer, Integer}] | []
  # visszaadja azon sorok sorszámát, amelyekben nem megfelelő számú sátor található
  defp e_rows(rs, tents) do
    for r <- Enum.with_index(rs) do
      {r, i} = r

      if(r > -1) do
        f = Enum.filter(tents, fn {x, _, _} -> x == i + 1 end)

        if(Enum.count(f) != r) do
          i + 1
        end
      else
        nil
      end
    end
  end

  @spec e_cols(cs :: [Integer], tents :: [{Integer, Integer, dir()}]) :: [{Integer, Integer}] | []
  # visszaadja azon oszlopok sorszámát, amelyekben nem megfelelő számú sátor található
  defp e_cols(cs, tents) do
    for c <- Enum.with_index(cs) do
      {c, i} = c

      if(c > -1) do
        f = Enum.filter(tents, fn {_, y, _} -> y == i + 1 end)

        if(Enum.count(f) != c) do
          i + 1
        end
      else
        nil
      end
    end
  end

  @spec e_touch(tents :: [{Integer, Integer, dir()}]) :: [{Integer, Integer}] | []
  # visszaadja a más sátrakkal érintkező sátrak koordinátáit
  defp e_touch(tents) do
    for t <- tents do
      {a, b, _} = t

      f =
        Enum.filter(tents, fn {x, y, _} ->
          (x == a and y == b + 1) or (x == a - 1 and y == b + 1) or
          (y == b and x == a + 1) or (x == a + 1 and y == b + 1)
        end)

      if(Enum.count(f) != 0) do
        c =
          for coord <- f do
            {x, y, _} = coord
            {x, y}
          end

        [{a, b} | c]
      end
    end
  end
end
